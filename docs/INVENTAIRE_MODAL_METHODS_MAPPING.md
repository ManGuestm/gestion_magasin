# Mapping Détaillé - Responsabilités par Méthode

## 📋 Liste Complète des Méthodes

### **INITIATE & LIFECYCLE** (3)

#### `initState()`
- **Ligne**: 104-122
- **Objectif**: Initialisation du widget
- **Responsabilités**:
  - ✅ Vérifier permission (_isVendeur)
  - ✅ Créer TabController(length: 4)
  - ✅ Lancer _loadData()
- **Durée estimation**: 50ms
- **À Extraire**: Vers Provider init

#### `dispose()`
- **Ligne**: 129-140
- **Objectif**: Nettoyage des ressources
- **Dispose Calls**:
  - ✅ _tabController
  - ✅ _scrollController
  - ✅ _inventaireScrollController
  - ✅ _inventaireSearchFocusNode
  - ✅ _mouvementsScrollController
  - ✅ _inventaireControllers (map complète)
- **⚠️ Manquant**: _mouvementsScrollController au complet?
- **À Extraire**: Consolidate avec State

#### `build()`
- **Ligne**: 375-407
- **Objectif**: Construire l'arbre widget principal
- **Retourne**: PopScope → Dialog → ScaffoldMessenger → Scaffold
- **Contient**: 4x TabBarView children
- **À Refactorer**: Réduire à delegation

---

### **CHARGEMENT DONNÉES** (5)

#### `_loadData()` [Async Orchestrator]
- **Ligne**: 141-175
- **Objectif**: Orchestrer chargement parallèle des données
- **Étapes**:
  1. Set isLoading = true
  2. Appeler 3 loaders async:
     - `_loadArticlesAsync()` → DatabaseService.getActiveArticles()
     - `_loadStocksAsync()` → select depart
     - `_loadCompanyInfoAsync()` → select soc
  3. Appeler `_processMetadataAsync(articles, stocks)` → dépôts + catégories
  4. setState() avec tous les résultats
  5. Lancer calculs async:
     - `_calculateStatsAsync()` → stats globales
     - `_applyFiltersAsync()` → filtrage initial
     - `_loadMouvementsAsync()` → historique
- **Durée estimation**: 500-1000ms total
- **À Extraire**: Vers InventaireService + Provider

#### `_loadArticlesAsync()`
- **Ligne**: 177-181
- **Objectif**: Charger tous les articles actifs
- **Source**: DatabaseService.database.getActiveArticles()
- **Retourne**: `List<Article>`
- **Note**: "Mode-aware" = ignoré (inventaire doit être complet)
- **À Extraire**: InventaireService

#### `_loadStocksAsync()`
- **Ligne**: 183-185
- **Objectif**: Charger répartition stocks par dépôt
- **Source**: select database.depart
- **Retourne**: `List<DepartData>`
- **Mapping**: DepartData { designation, depots, stocksu1/2/3 }
- **À Extraire**: InventaireService

#### `_loadCompanyInfoAsync()`
- **Ligne**: 187-210
- **Objectif**: Charger infos entreprise pour exports
- **Source**: select soc LIMIT 1
- **Retourne**: `Map<String, dynamic>` avec { nom, adresse, tel, email, nif, stat, rcs }
- **Fallback**: Valeurs par défaut si erreur
- **À Extraire**: ConfigService

#### `_processMetadataAsync()`
- **Ligne**: 212-254
- **Objectif**: Extraire dépôts & catégories uniques
- **Algorithme**:
  - Itérer stocks par batch (batchSize=100)
    - Extraire dépôt unique
  - Itérer articles par batch (batchSize=100)
    - Extraire catégorie unique
  - Trier alphanumérique
  - Ajouter "Tous"/"Toutes" en début
- **Retourne**: `{ 'depots': [...], 'categories': [...] }`
- **À Extraire**: InventaireService

---

### **CALCULS & STATISTIQUES** (2)

#### `_calculateStatsAsync()`
- **Ligne**: 256-263
- **Objectif**: Wrapper async pour calcul stats
- **Appelle**: `_calculateStats(_articles, stock)`
- **setState()**: Met à jour _stats
- **À Extraire**: InventaireService

#### `_calculateStats()`
- **Ligne**: 265-297
- **Objectif**: Calculer métriques globales
- **Calcule**:
  - valeurTotale = sum(stockTotalU3 * cmup)
  - articlesEnStock = count(stock > 0)
  - articlesRupture = count(stock <= 0)
  - articlesAlerte = count(0 < stock <= usec)
  - totalArticles = articles.length
- **Batch Processing**: Par 100 articles
- **Retourne**: `Map<String, dynamic>` avec { valeurTotale, articlesEnStock, ... }
- **À Extraire**: InventaireService

---

### **FILTRAGE & RECHERCHE** (4)

#### `_applyFilters()` [Sync Wrapper]
- **Ligne**: 299-301
- **Objectif**: Wrapper qui appelle async
- **Appelle**: `_applyFiltersAsync()`
- **À Refactorer**: Supprimer inutile

#### `_applyFiltersAsync()` [Core Logic]
- **Ligne**: 303-366
- **Objectif**: Filtrer articles par search + dépôt + catégorie
- **Logic**:
  1. Check cache:
     ```
     if (_searchQuery == _lastSearchQuery &&
         _selectedCategorie == _lastSelectedCategorie &&
         _selectedDepot == _lastSelectedDepot) return;
     ```
  2. Filter par batch (batchSize=200):
     ```
     where article matches:
       - search: designation OR categorie
       - depot: selectedDepot == 'Tous' OR stockDepot
       - categorie: selectedCategorie == 'Toutes' OR article.categorie
     ```
  3. setState() + reset pagination
  4. Update cache variables
- **Performance**: O(n) où n = articles.length
- **À Extraire**: InventaireService

#### `_applyMouvementsFilters()` [Mouvement Filter]
- **Ligne**: 1918-1970
- **Objectif**: Filtrer mouvements historiques
- **Filtre par**:
  - Search: designation, reference, depots
  - Type: 'Tous' OR type spécifique (ACHAT, VENTE, etc)
  - DateRange: if dateDebut && dateFin
  - Depot: selectedDepot
- **Tri**: Par date décroissante (mouvement.daty desc)
- **Gestion timestamp**: Conversion string → DateTime
- **À Extraire**: MouvementService

---

### **TAB STOCK** (3)

#### `_buildStockTab()`
- **Ligne**: 478-508
- **Objectif**: Construire tab Stock
- **Contient**: Délégation à widget StockTab externe
- **Props Passées**:
  - Données: isLoading, stats, filteredArticles, stock
  - Filtres: selectedDepot, selectedCategorie, depots, categories
  - Pagination: currentPage, itemsPerPage
  - Callbacks: onSearchChanged, onDepotChanged, onCategorieChanged, onExport, onPageChanged
- **À Supprimer**: Refactorer dans InventaireModal

#### `buildArticleRow()`
- **Ligne**: 510-570
- **Objectif**: Créer une ligne DataTable pour article
- **Logique**:
  1. Chercher stock dépôt spécifique
  2. Si pas trouvé: utiliser article.stocksu1/2/3 global
  3. Convertir en U3 (stock total)
  4. Calculer valeur = stockU3 * cmup
  5. Déterminer status (En stock / Alerte / Rupture)
  6. Retourner DataRow avec cells formatées
- **À Extraire**: StockTabWidget

#### `_changePage()`
- **Ligne**: 572-589
- **Objectif**: Paginer le tab Stock
- **Logic**:
  1. Check if loading → return
  2. setState() avec newPage
  3. setState() avec isLoadingPage = false (50ms delay)
- **À Extraire**: StockTabWidget

---

### **TAB INVENTAIRE** (11)

#### `_buildInventaireTab()`
- **Ligne**: 591-598
- **Objectif**: Construire tab Inventaire
- **Conditional**:
  - Si !inventaireMode: Afficher button "Démarrer" + mode lecture
  - Si inventaireMode: Afficher _buildInventaireList()
- **À Extraire**: InventaireTabWidget

#### `_buildInventaireHeader()`
- **Ligne**: 600-713
- **Objectif**: En-tête + contrôles tab Inventaire
- **Contient**:
  - Button "Démarrer Inventaire" (si !mode)
  - DropDown dépôt (si mode)
  - TextField recherche (si mode)
  - Boutons: Import Excel, Annuler, Sauvegarder (si mode)
  - Stats: articles total, écarts détectés
- **À Extraire**: InventaireTabWidget

#### `_buildInventaireList()`
- **Ligne**: 720-730
- **Objectif**: Router liste inventaire
- **Conditional**:
  - Si !inventaireMode: Afficher message "Démarrer inventaire"
  - Si inventaireMode: Afficher _buildVirtualizedInventaireList()
- **À Extraire**: InventaireTabWidget

#### `_buildVirtualizedInventaireList()`
- **Ligne**: 732-745
- **Objectif**: ListView virtualisée pour inventaire
- **Pagination**:
  - Calculate: startIndex = page * 25, endIndex = startIndex + 25
  - sublist(startIndex, endIndex)
- **ItemBuilder**: _buildInventaireTableHeader() + articles
- **À Extraire**: InventaireTabWidget

#### `_buildInventaireTableHeader()`
- **Ligne**: 764-809
- **Objectif**: En-têtes colonnes (non-scrollable)
- **Colonnes**: Article, Réf, U1/2/3 Théorique, U1/2/3 Physique, Écart
- **À Extraire**: InventaireTabWidget

#### `_buildInventaireListItem()`
- **Ligne**: 811-1014
- **Objectif**: Construire une ligne inventaire
- **Très Complexe** (200+ lignes):
  - Récupérer stocks théoriques dépôt
  - Récupérer saisies physiques de _inventairePhysique
  - Calculer écarts = physique - théorique
  - Créer 3 TextFields (U1, U2, U3)
  - Afficher calculs en temps réel
  - Validation input
- **À Extraire**: InventaireTabWidget en widget séparé

#### `_startInventaire()`
- **Ligne**: 1616-1620
- **Objectif**: Activer mode inventaire
- **Actions**:
  - Set inventaireMode = true
  - Set dateInventaire = DateTime.now()
  - Clear _inventairePhysique
- **À Extraire**: Provider action

#### `_cancelInventaire()`
- **Ligne**: 1790-1795
- **Objectif**: Annuler mode inventaire
- **Actions**:
  - Set inventaireMode = false
  - Clear dateInventaire
  - Clear _inventairePhysique
- **À Extraire**: Provider action

#### `_saveInventaire()`
- **Ligne**: 1797-1876
- **Objectif**: Sauvegarder inventaire en DB
- **Logique**:
  1. Transaction DB
  2. Pour chaque article avec saisie:
     - Calculer écart (physique - théorique)
     - Créer Stock record
     - Insert en DB
  3. setState() inventaireMode = false
  4. _loadData() pour rafraîchir
- **À Extraire**: InventaireService

#### `_importInventaire()`
- **Ligne**: 1622-1688
- **Objectif**: Importer inventaire depuis Excel
- **Logique**:
  1. FilePicker.pickFiles()
  2. Décoder Excel bytes
  3. Parser sheet rows (skip header)
  4. Pour chaque row:
     - Extract designation, u1, u2, u3
     - Chercher article matching
     - Stocker en _inventairePhysique
  5. setState() dateInventaire
- **À Extraire**: InventaireService

#### `_scrollToArticle()`
- **Ligne**: 1207-1231
- **Objectif**: Scroll to article spécifique
- **Logique**:
  1. Chercher articleIndex dans filteredArticles
  2. Calculer targetPage
  3. Si page changée: setState()
  4. Animate scroll à targetOffset
- **À Extraire**: InventaireTabWidget

#### `_changeInventairePage()`
- **Ligne**: 1188-1205
- **Objectif**: Paginer le tab Inventaire
- **Similar to _changePage()**
- **À Extraire**: InventaireTabWidget

#### `buildInventaireRow()` [Deprecated]
- **Ligne**: 1024-1150
- **Objectif**: DataRow (non utilisée - ListView utilisée à la place)
- **À Supprimer**: Code mort

---

### **TAB MOUVEMENTS** (11)

#### `_buildMouvementsTab()`
- **Ligne**: 1235-1241
- **Objectif**: Construire tab Mouvements
- **Contient**: Header + Filters + Liste
- **À Extraire**: MouvementsTabWidget

#### `_buildMouvementsHeader()`
- **Ligne**: 1243-1281
- **Objectif**: En-tête + export
- **Affiche**: Nombre mouvements + button export
- **À Extraire**: MouvementsTabWidget

#### `_buildMouvementsFilters()`
- **Ligne**: 1283-1396
- **Objectif**: Filtres avancés
- **Filtres**:
  - TextField recherche
  - DropDown type (Tous, ACHAT, VENTE, etc)
  - DateRange picker
  - DropDown dépôt
- **À Extraire**: MouvementsTabWidget

#### `_buildMouvementsList()`
- **Ligne**: 1398-1425
- **Objectif**: Router liste mouvements
- **Conditional**:
  - Si isLoadingMouvements: CircularProgressIndicator
  - Si empty: "Aucun mouvement"
  - Sinon: _buildVirtualizedMouvementsList()
- **À Extraire**: MouvementsTabWidget

#### `_buildVirtualizedMouvementsList()`
- **Ligne**: 1427-1445
- **Objectif**: ListView virtualisée mouvements
- **Similar to stock & inventaire**
- **À Extraire**: MouvementsTabWidget

#### `_buildMouvementsTableHeader()`
- **Ligne**: 1447-1486
- **Objectif**: En-têtes colonnes
- **Colonnes**: Date, Type, Qte Entrée, Qte Sortie, Motif, Dépôt
- **À Extraire**: MouvementsTabWidget

#### `_buildMouvementListItem()`
- **Ligne**: 1488-1569
- **Objectif**: Ligne mouvement
- **Affiche**: Détails mouvement (date, type, quantités)
- **À Extraire**: MouvementsTabWidget

#### `_changeMouvementsPage()`
- **Ligne**: 1571-1579
- **Objectif**: Paginer mouvements
- **À Extraire**: MouvementsTabWidget

#### `_selectDateRange()`
- **Ligne**: 1981-2000
- **Objectif**: Picker plage dates
- **Retourne**: DateTimeRange
- **Appelle**: _applyMouvementsFilters()
- **À Extraire**: MouvementsTabWidget

#### `_loadMouvementsAsync()`
- **Ligne**: 1896-1914
- **Objectif**: Charger mouvements historiques
- **Source**: DatabaseService.database.getAllStocks()
- **setState()**: _mouvements + isLoadingMouvements
- **À Extraire**: MouvementService

#### `_applyMouvementsFilters()` [Voir section Filtrage]

---

### **TAB RAPPORTS** (2)

#### `_buildRapportsTab()`
- **Ligne**: 1611-1614
- **Objectif**: Déléguer à widget RapportsTab
- **Props**: stats, articles, stock, depots
- **À Laisser**: Déjà externe

#### `_exportRapports()`
- **Ligne**: 2002-2004
- **Objectif**: Placeholder
- **Actuellement**: Affiche message "À implémenter"
- **À Implémenter**: Dans ExportService

---

### **EXPORTS** (6)

#### `_exportStock()` [Export Router]
- **Ligne**: 2020-2032
- **Objectif**: Choix format export
- **Dialog**: "Choisir format Excel/PDF"
- **Appelle**: _exportToExcel() OU _exportToPdf()
- **À Extraire**: ExportService

#### `_exportToExcel()` [Excel Generator]
- **Ligne**: 2034-2115
- **Objectif**: Générer fichier Excel
- **Logique**:
  1. Excel.createExcel()
  2. Ajouter en-têtes professionnels (nom entreprise, adresse, date)
  3. Ajouter en-têtes colonnes (Article, Catégorie, Stock U1/2/3, CMUP, Valeur, Statut)
  4. Pour chaque article:
     - Remplir colonnes
     - Calculer valeur = stockTotal * cmup
     - Déterminer status
  5. Sauvegarder en Documents/{date_inventaire.xlsx}
- **Format Filename**: `inventaire_DD_MM_YYYY_HH_MM.xlsx`
- **À Extraire**: ExportService

#### `_exportToPdf()` [PDF Generator]
- **Ligne**: 2117-2272
- **Objectif**: Générer fichier PDF
- **Logique**:
  1. pw.Document()
  2. Paginer (40 items/page)
  3. Pour chaque page:
     - Ajouter header (titre, date, entreprise)
     - Créer table articles
     - Ajouter page breaks
  4. Sauvegarder en Documents
- **À Extraire**: ExportService

#### `_exportMouvements()` [Router Mouvements]
- **Ligne**: 2274-2293
- **Objectif**: Choix format export mouvements
- **Dialog**: Choose format
- **Appelle**: _exportMouvementsToExcel() OU _exportMouvementsToPdf()
- **À Extraire**: ExportService

#### `_exportMouvementsToExcel()`
- **Ligne**: 2295-2357
- **Objectif**: Excel mouvements
- **À Implémenter**: Similaire à _exportToExcel()
- **À Extraire**: ExportService

#### `_exportMouvementsToPdf()`
- **Ligne**: 2359-2476
- **Objectif**: PDF mouvements
- **À Implémenter**: Similaire à _exportToPdf()
- **À Extraire**: ExportService

---

### **UTILITAIRES** (6)

#### `_isVendeur()`
- **Ligne**: 123-126
- **Objectif**: Vérifier rôle utilisateur
- **Check**: authService.currentUserRole == 'Vendeur'
- **À Extraire**: AuthService check existant

#### `_getController()`
- **Ligne**: 2007-2011
- **Objectif**: Lazy-create TextEditingController
- **Cache**: En _inventaireControllers map
- **À Refactorer**: Utiliser Provider ou State

#### `_showError()`
- **Ligne**: 1888-1891
- **Objectif**: Afficher SnackBar erreur
- **Utilise**: _scaffoldMessengerKey.currentState
- **À Extraire**: Utiliser ScaffoldMessenger context

#### `_showSuccess()`
- **Ligne**: 1893-1896
- **Objectif**: Afficher SnackBar succès
- **Similar to _showError()**

#### `_formatStockDisplay()`
- **Ligne**: 2478-2504
- **Objectif**: Formater affichage stock
- **Utilise**: StockConverter.calculerStockTotalU3() + convertirStockOptimal() + formaterAffichageStock()
- **À Extraire**: StockConverter déjà existant

---

## 📊 Résumé Extraction

### À Extraire en Fichiers Séparés

```
✅ InventaireService (lib/services/)
   - _loadArticlesAsync
   - _loadStocksAsync
   - _processMetadataAsync
   - _calculateStats
   - _applyFiltersAsync
   - _startInventaire → state action
   - _saveInventaire
   - _importInventaire

✅ MouvementService (lib/services/)
   - _loadMouvementsAsync
   - _applyMouvementsFilters

✅ ExportService (lib/services/)
   - _exportToExcel
   - _exportToPdf
   - _exportMouvementsToExcel
   - _exportMouvementsToPdf

✅ StockTabWidget (lib/widgets/modals/tabs/)
   - _buildStockTab
   - buildArticleRow
   - _changePage
   - (réutiliser StockTab existant)

✅ InventaireTabWidget (lib/widgets/modals/tabs/)
   - _buildInventaireTab
   - _buildInventaireHeader
   - _buildInventaireList
   - _buildVirtualizedInventaireList
   - _buildInventaireTableHeader
   - _buildInventaireListItem
   - _changeInventairePage
   - _scrollToArticle

✅ MouvementsTabWidget (lib/widgets/modals/tabs/)
   - _buildMouvementsTab
   - _buildMouvementsHeader
   - _buildMouvementsFilters
   - _buildMouvementsList
   - _buildVirtualizedMouvementsList
   - _buildMouvementsTableHeader
   - _buildMouvementListItem
   - _changeMouvementsPage
   - _selectDateRange

✅ InventaireState (lib/models/)
   - Consolidate 40 variables
   - Add computed properties

✅ InventaireProvider (lib/providers/)
   - InventaireNotifier
   - inventaireProvider
```

---

## 📈 Impact Ligne par Extraction

| Phase | Extraction | Avant | Après | Réduction |
|-------|-----------|-------|-------|-----------|
| 2 | InventaireState | 2504 | 2200 | -12% |
| 3-5 | Services | 2200 | 1200 | -45% |
| 6 | Tabs separés | 1200 | 600 | -50% |
| 8 | Provider | 600 | 300 | -50% |
| **TOTAL** | **Refactor** | **2504** | **~300-400** | **-85%** |

Final InventaireModal = ~300-400 lignes (vs 2504)
