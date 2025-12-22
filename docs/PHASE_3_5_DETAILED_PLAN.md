# Plan Détaillé Phases 3-5 : Extraction Tabs

## 📋 Phase 3 : Extraire StockTab (6-8h)

### 3.1 Objectif
Créer widget autonome `StockTabNew` réutilisable avec InventaireState

### 3.2 Fichier à Créer
**`lib/widgets/modals/tabs/stock_tab_new.dart`** (300 lignes estimées)

### 3.3 Structure Proposée

```dart
/// Widget immutable affichant table articles + pagination
/// 
/// Réutilise StockTab existant mais refactorisé pour:
/// - Utiliser InventaireState (au lieu variables globales)
/// - Callbacks au parent pour mutations
/// - Virtualisation avec pagination
class StockTabNew extends StatefulWidget {
  // === DONNÉES ===
  final InventaireState state;
  
  // === CALLBACKS ===
  final Function(String) onSearchChanged;
  final Function(String) onDepotChanged;
  final Function(String) onCategorieChanged;
  final Function(int) onPageChanged;
  final Function() onExport;
  final Function(int?) onHoverChanged;
  
  const StockTabNew({
    required this.state,
    required this.onSearchChanged,
    required this.onDepotChanged,
    required this.onCategorieChanged,
    required this.onPageChanged,
    required this.onExport,
    required this.onHoverChanged,
  });

  @override
  State<StockTabNew> createState() => _StockTabNewState();
}

class _StockTabNewState extends State<StockTabNew> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // En-tête: Filtres + Stats
    // Corps: Table ou ListView
    // Pied: Pagination
  }
  
  // Méthodes à déplacer:
  // - _buildStockHeader() → local à ce widget
  // - buildArticleRow() → local à ce widget
  // - _changePage() → callback au parent
}
```

### 3.4 Code à Déplacer

#### Source: inventaire_modal.dart
- Lignes 478-508: `_buildStockTab()` → Supprimer (sera ce widget)
- Lignes 510-570: `buildArticleRow()` → Copier comme méthode locale
- Lignes 572-589: `_changePage()` → Callback `onPageChanged`

#### Nouvelles Méthodes
```dart
Widget _buildStockTabHeader() {
  // Filtre recherche
  // DropDown dépôt
  // DropDown catégorie
  // Button export
  // Stats box
}

Widget _buildStockList() {
  if (widget.state.isLoading) return CircularProgressIndicator();
  if (widget.state.filteredArticles.isEmpty) return EmptyState();
  
  return _buildVirtualizedStockList();
}

Widget _buildVirtualizedStockList() {
  // ListView virtualisée avec widget.state.stockPageItems
}

DataRow _buildArticleRow(Article article) {
  // Logique du buildArticleRow() original
}

Widget _buildStockPagination() {
  // Buttons pagination
}
```

### 3.5 Intégration dans Modal

**Avant:**
```dart
Widget _buildStockTab() {
  return StockTab(
    filteredArticles: _filteredArticles,
    onSearchChanged: (value) => setState(...)
    // ...
  );
}
```

**Après:**
```dart
Widget _buildStockTab() {
  return StockTabNew(
    state: _state,  // InventaireState
    onSearchChanged: (q) => _notifier.applyStockFilters(q, ...),
    onDepotChanged: (d) => _notifier.applyStockFilters(_, d, ...),
    onPageChanged: (p) => _notifier.changeStockPage(p),
    onExport: () => _notifier.exportStock(),
    onHoverChanged: (i) => _notifier.setHoveredStockIndex(i),
  );
}
```

### 3.6 Tests à Ajouter
```dart
// test/widgets/modals/tabs/stock_tab_new_test.dart

testWidgets('StockTabNew - affiche articles filtrés', (tester) async {
  final state = InventaireState.initial().copyWith(
    filteredArticles: [mockArticle1, mockArticle2],
  );
  
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StockTabNew(
          state: state,
          onSearchChanged: (_) {},
          onPageChanged: (_) {},
          // ...
        ),
      ),
    ),
  );
  
  expect(find.text('Article1'), findsOneWidget);
});
```

---

## 📋 Phase 4 : Extraire InventaireTab (7-9h)

### 4.1 Objectif
Créer widget autonome `InventaireTabNew` pour saisie physique

### 4.2 Fichier à Créer
**`lib/widgets/modals/tabs/inventaire_tab_new.dart`** (400 lignes)

### 4.3 Structure Proposée

```dart
class InventaireTabNew extends StatefulWidget {
  // === DONNÉES ===
  final InventaireState state;
  
  // === CALLBACKS ===
  final Function() onStartInventaire;
  final Function() onCancelInventaire;
  final Function() onSaveInventaire;
  final Function() onImportInventaire;
  final Function(String designation, Map<String, double> values) onSaisie;
  final Function(String depot) onDepotChanged;
  final Function(int page) onPageChanged;
  final Function(int?) onHoverChanged;
  
  const InventaireTabNew({
    required this.state,
    required this.onStartInventaire,
    required this.onCancelInventaire,
    required this.onSaveInventaire,
    required this.onImportInventaire,
    required this.onSaisie,
    required this.onDepotChanged,
    required this.onPageChanged,
    required this.onHoverChanged,
  });

  @override
  State<InventaireTabNew> createState() => _InventaireTabNewState();
}

class _InventaireTabNewState extends State<InventaireTabNew> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, TextEditingController> _controllers = {};
  
  @override
  void dispose() {
    _scrollController.dispose();
    for (var c in _controllers.values) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.state.inventaireMode) {
      return _buildStartMode();
    }
    return _buildEditMode();
  }
  
  Widget _buildStartMode() {
    // Message: "Démarrer inventaire"
    // Button: "Démarrer"
  }
  
  Widget _buildEditMode() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildList()),
      ],
    );
  }
}
```

### 4.4 Code à Déplacer

#### Source: inventaire_modal.dart
- Lignes 591-598: `_buildInventaireTab()` → Structure principale
- Lignes 600-713: `_buildInventaireHeader()` → Refactor pour callbacks
- Lignes 732-745: `_buildVirtualizedInventaireList()` → Copier
- Lignes 811-1014: `_buildInventaireListItem()` → Refactor complexe
- Lignes 1188-1205: `_changeInventairePage()` → Callback
- Lignes 1207-1231: `_scrollToArticle()` → Méthode locale
- Lignes 1616-1620: `_startInventaire()` → Callback
- Lignes 1790-1795: `_cancelInventaire()` → Callback
- Lignes 1622-1688: `_importInventaire()` → Callback + Service
- Lignes 1797-1876: `_saveInventaire()` → Callback + Service

### 4.5 Nouvelles Méthodes

```dart
Widget _buildHeader() {
  return Container(
    padding: EdgeInsets.all(16),
    child: Column(
      children: [
        // Dépôt selection
        // Recherche
        // Boutons: Importer, Annuler, Sauvegarder
        // Stats écarts
      ],
    ),
  );
}

Widget _buildList() {
  return _buildVirtualizedInventaireList();
}

Widget _buildVirtualizedInventaireList() {
  final items = widget.state.inventairePageItems;
  
  return ListView.builder(
    controller: _scrollController,
    itemCount: items.length + 1,
    itemBuilder: (context, i) {
      if (i == 0) return _buildTableHeader();
      return _buildInventaireListItem(items[i - 1]);
    },
  );
}

Widget _buildInventaireListItem(Article article) {
  // COMPLEXE: 200+ lignes
  // - Chercher stock dépôt
  // - Chercher saisie physique
  // - Créer 3 TextFields (U1, U2, U3)
  // - Calculer écarts en temps réel
  // - Validation input
  // - Hover effects
}

Widget _buildTableHeader() {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        // Colonnes: Article, Réf, U1 Théo, U2 Théo, U3 Théo,
        //           U1 Phys, U2 Phys, U3 Phys, Écart
      ],
    ),
  );
}

Widget _buildInventairePagination() {
  final totalPages = widget.state.totalInventairePages;
  
  return Row(
    children: [
      for (int p = 0; p < totalPages; p++)
        ElevatedButton(
          onPressed: () => widget.onPageChanged(p),
          child: Text('$p'),
        ),
    ],
  );
}

TextEditingController _getController(String key, double value) {
  if (!_controllers.containsKey(key)) {
    _controllers[key] = TextEditingController(
      text: value > 0 ? value.toString() : '',
    );
  }
  return _controllers[key]!;
}
```

### 4.6 Gestion TextEditingControllers

**Important:** Chaque item a 3 TextFields (U1, U2, U3)
- Clé: `${article.designation}_${depot}_u1/2/3`
- Créés à la demande
- Libérés dans dispose()
- Synchronisés avec InventairePhysique

**Alternative Meilleure:**
Utiliser Form + formKey pour validation au lieu de TextEditingControllers individuels.

### 4.7 Intégration Modal

```dart
Widget _buildInventaireTab() {
  return InventaireTabNew(
    state: _state,
    onStartInventaire: () => _notifier.startInventaire(),
    onCancelInventaire: () => _notifier.cancelInventaire(),
    onSaveInventaire: () => _notifier.saveInventaire(),
    onImportInventaire: () => _notifier.importInventaire(),
    onSaisie: (designation, values) => _notifier.saisieInventaire(designation, values),
    onDepotChanged: (depot) => _notifier.selectDepotInventaire(depot),
    onPageChanged: (p) => _notifier.changeInventairePage(p),
    onHoverChanged: (i) => _notifier.setHoveredInventaireIndex(i),
  );
}
```

---

## 📋 Phase 5 : Extraire MouvementsTab (5-7h)

### 5.1 Objectif
Créer widget autonome `MouvementsTabNew` pour historique

### 5.2 Fichier à Créer
**`lib/widgets/modals/tabs/mouvements_tab_new.dart`** (350 lignes)

### 5.3 Structure

```dart
class MouvementsTabNew extends StatefulWidget {
  final InventaireState state;
  
  // === FILTRES CALLBACKS ===
  final Function(String) onSearchChanged;
  final Function(String) onTypeChanged;
  final Function(DateTimeRange?) onDateRangeChanged;
  final Function(String) onDepotChanged;
  final Function() onApplyFilters;
  final Function() onExport;
  final Function(int) onPageChanged;
  final Function(int?) onHoverChanged;

  const MouvementsTabNew({required this.state, ...});

  @override
  State<MouvementsTabNew> createState() => _MouvementsTabNewState();
}

class _MouvementsTabNewState extends State<MouvementsTabNew> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildFilters(),
        Expanded(child: _buildList()),
      ],
    );
  }
}
```

### 5.4 Code à Déplacer

#### Source: inventaire_modal.dart
- Lignes 1235-1241: `_buildMouvementsTab()` → Structure
- Lignes 1243-1281: `_buildMouvementsHeader()` → Copier
- Lignes 1283-1396: `_buildMouvementsFilters()` → Refactor
- Lignes 1427-1445: `_buildVirtualizedMouvementsList()` → Copier
- Lignes 1447-1486: `_buildMouvementsTableHeader()` → Copier
- Lignes 1488-1569: `_buildMouvementListItem()` → Copier
- Lignes 1571-1579: `_changeMouvementsPage()` → Callback
- Lignes 1981-2000: `_selectDateRange()` → Méthode locale
- Lignes 1918-1970: `_applyMouvementsFilters()` → Callback + Service

### 5.5 Nouvelles Méthodes

```dart
Widget _buildHeader() {
  // Titre "Mouvements de Stock"
  // Nombre mouvements
  // Button export
}

Widget _buildFilters() {
  return Container(
    padding: EdgeInsets.all(16),
    child: Column(
      children: [
        // TextField recherche
        // DropDown type (Tous, ACHAT, VENTE, ...)
        // DateRange picker
        // DropDown dépôt
        // Button "Appliquer Filtres"
      ],
    ),
  );
}

Widget _buildList() {
  if (widget.state.isLoadingMouvements) {
    return CircularProgressIndicator();
  }
  if (widget.state.filteredMouvements.isEmpty) {
    return EmptyState('Aucun mouvement');
  }
  return _buildVirtualizedMouvementsList();
}

Widget _buildVirtualizedMouvementsList() {
  // Copier depuis inventaire_modal.dart lignes 1427-1445
}

Widget _buildMouvementListItem(Stock mouvement, int index) {
  // Copier depuis inventaire_modal.dart lignes 1488-1569
}

Future<void> _selectDateRange() async {
  final DateTimeRange? picked = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2020),
    lastDate: DateTime.now(),
    initialDateRange: widget.state.dateRangeMouvement,
  );
  
  if (picked != null) {
    widget.onDateRangeChanged(picked);
  }
}

Widget _buildMouvementsPagination() {
  // Buttons pagination
}
```

### 5.6 Filtres Avancés

```dart
Widget _buildFilters() {
  return Container(
    padding: EdgeInsets.all(16),
    child: Column(
      children: [
        // Ligne 1: Recherche
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: widget.onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
          ],
        ),
        // Ligne 2: Type + Dépôt
        Row(
          children: [
            Expanded(
              child: DropdownButton(
                items: _typesMovement.map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(t),
                )).toList(),
                onChanged: widget.onTypeChanged,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: DropdownButton(
                items: widget.state.depots.map((d) => DropdownMenuItem(
                  value: d,
                  child: Text(d),
                )).toList(),
                onChanged: widget.onDepotChanged,
              ),
            ),
          ],
        ),
        // Ligne 3: Date range
        Button(
          onPressed: _selectDateRange,
          child: Text('Choisir plage dates'),
        ),
      ],
    ),
  );
}
```

### 5.7 Intégration Modal

```dart
Widget _buildMouvementsTab() {
  return MouvementsTabNew(
    state: _state,
    onSearchChanged: (q) => _notifier.setMouvementsSearch(q),
    onTypeChanged: (t) => _notifier.selectMouvementType(t),
    onDateRangeChanged: (dr) => _notifier.setDateRangeMouvement(dr),
    onDepotChanged: (d) => _notifier.selectDepotMouvement(d),
    onApplyFilters: () => _notifier.applyMouvementsFilters(),
    onExport: () => _notifier.exportMouvements(),
    onPageChanged: (p) => _notifier.changeMouvementsPage(p),
    onHoverChanged: (i) => _notifier.setHoveredMouvementIndex(i),
  );
}
```

---

## 🔄 Workflow Phases 3-5

### Ordre Recommandé

**Jour 1: Phase 3 (6-8h)**
```
8h-12h:   Créer StockTabNew structure + build
12h-14h:  Tester + debug
14h-16h:  Intégrer dans Modal + Tests
```

**Jour 2: Phase 4 (7-9h)**
```
8h-12h:   Créer InventaireTabNew base + header
12h-14h:  _buildInventaireListItem (complexe)
14h-17h:  Tests + gestion TextEditingControllers
```

**Jour 3: Phase 5 (5-7h)**
```
8h-11h:   Créer MouvementsTabNew + ListView
11h-13h:  Filtres avancés
13h-15h:  Tests + pagination
```

### Milestones de Validation

- [x] Phase 3: StockTabNew compile + tests passent
- [x] Phase 4: InventaireTabNew compile + TextControllers work
- [x] Phase 5: MouvementsTabNew compile + filters work
- [x] Modal principale: refactorisée vers appel des 3 widgets

### Réduction Ligne Estimée

```
Avant: 2504 lignes
Phase 3: -300 lignes (Stock)
Phase 4: -400 lignes (Inventaire)
Phase 5: -350 lignes (Mouvements)
─────────────────────────
Après:  ~1454 lignes

Phase 6-8 (Services + Provider): -600 lignes de plus
─────────────────────────
Final:  ~850 lignes
```

---

## ✅ Checklist Phases 3-5

### Phase 3
- [ ] Créer `stock_tab_new.dart`
- [ ] Déplacer `buildArticleRow()` & pagination
- [ ] Créer `_buildStockTabHeader()`
- [ ] Tester avec InventaireState
- [ ] Intégrer dans Modal.build()

### Phase 4
- [ ] Créer `inventaire_tab_new.dart`
- [ ] Implémenter _buildInventaireListItem()
- [ ] Gérer TextEditingControllers lifecycle
- [ ] Intégrer validation + écarts affichage
- [ ] Tester saisie + save

### Phase 5
- [ ] Créer `mouvements_tab_new.dart`
- [ ] Implémenter filtres avancés
- [ ] Ajouter date range picker
- [ ] Tester pagination + filtering
- [ ] Intégrer export

---

## 🎯 Notes Importantes

1. **State vs Notifier**
   - Phases 3-5 utilisent callbacks
   - Phase 8 convertira en Provider/Riverpod
   - Callbacks → Provider actions

2. **TextEditingControllers**
   - Phase 4 doit gérer dispose() soigneusement
   - Considérer Form + validation plutôt que controllers directs

3. **Services**
   - Phases 3-5 font juste UI
   - Logique métier reste dans Modal pour l'instant
   - Phase 6 extraira logique vers Services

4. **Tests**
   - Commencer tests widget dès Phase 3
   - Mock InventaireState pour tests
   - Vérifier virtualization performance

---

**Status:** Ready for Phase 3 Implementation
